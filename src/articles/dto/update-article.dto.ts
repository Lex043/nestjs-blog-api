import { IsInt, IsNotEmpty } from 'class-validator';

export class UpdateArticleDto {
    @IsNotEmpty()
    title: string;

    @IsNotEmpty()
    article: string;
}
