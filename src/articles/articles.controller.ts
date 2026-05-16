import {
    Body,
    Controller,
    Delete,
    Get,
    Param,
    Patch,
    Post,
} from '@nestjs/common';
import { CreateArticleDto } from './dto/create-article.dto';
import { UpdateArticleDto } from './dto/update-article.dto';
import { ArticlesService } from './articles.service';

@Controller('articles')
export class ArticlesController {
    constructor(private articlesService: ArticlesService) {}
    @Get()
    async getArticles() {
        return this.articlesService.findAll();
    }

    @Get(':id')
    async getArticle(@Param('id') id: number) {
        return this.articlesService.findOne(id);
    }

    @Post()
    async createArticle(@Body() data: CreateArticleDto) {
        return await this.articlesService.create(data);
    }

    @Patch(':id')
    async updateArticle(
        @Param('id') id: number,
        @Body() updateArticle: UpdateArticleDto,
    ) {
        return await this.articlesService.update(id, updateArticle);
    }

    @Delete(':id')
    async deleteArticle(@Param('id') id: number) {
        return this.articlesService.remove(id);
    }
}
